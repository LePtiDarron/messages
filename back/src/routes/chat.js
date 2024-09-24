const express = require('express');
const router = express.Router();
const Chat = require('./../models/Chat');
const User = require('./../models/User');

router.get('/', async (req, res) => {
    const { participants } = req.query;

    if (!participants) {
        return res.status(400).json({ message: 'Champ(s) manquants' });
    }

    const participantArray = participants.split(',');
    if (participantArray.length < 2) {
        return res.status(400).json({ message: 'Format invalide' });
    }

    try {
        const users = await User.find({ email: { $in: participantArray } });
        const participantsIDs = users.map(user => user._id);

        if (participantsIDs.length !== participantArray.length) {
            return res.status(404).json({ message: 'Un ou plusieurs utilisateurs non trouvés' });
        }

        let chat = await Chat.findOne({ participants: { $all: participantsIDs } });

        if (!chat || chat.participants.length != participantsIDs.length) {
            chat = new Chat({
                participants: participantsIDs,
                messages: [],
                readBy: participantsIDs,
                group: false,
            });
            await chat.save();
        }

        return res.json({ chatId: chat._id });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.get('/new-group', async (req, res) => {
    const { participants } = req.query;

    if (!participants) {
        return res.status(400).json({ message: 'Champ(s) manquants' });
    }

    const participantArray = participants.split(',');
    if (participantArray.length < 2) {
        return res.status(400).json({ message: 'Format invalide' });
    }

    try {
        const users = await User.find({ email: { $in: participantArray } });

        const userMap = {};
        users.forEach(user => {
            userMap[user.email] = user._id;
        });

        const participantsIDs = participantArray.map(email => userMap[email]).filter(id => id);

        if (participantsIDs.length !== participantArray.length) {
            return res.status(404).json({ message: 'Un ou plusieurs utilisateurs non trouvés' });
        }

        const chat = new Chat({
            participants: participantsIDs,
            messages: [],
            readBy: participantsIDs,
            group: true,
        });
        await chat.save();

        return res.json({ chatId: chat._id });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.get('/all', async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        const chats = await Chat.find({ participants: user._id })
            .populate('participants', 'firstName lastName email picture')
            .populate({
                path: 'messages.sender',
                select: 'firstName lastName picture email',
            })
            .lean();
        if (chats.length === 0) {
            return res.status(404).json({ message: 'Aucune conversation trouvée' });
        }

        const formattedChats = chats.map(chat => ({
            chatId: chat._id,
            participants: chat.participants.map(participant => ({
                firstName: participant.firstName,
                lastName: participant.lastName,
                email: participant.email,
                picture: participant.picture,
            })),
            lastMessage: chat.messages.length > 0 ? {
                date: chat.messages[0].date,
                content: chat.messages[0].content,
                senderName: `${chat.messages[0].sender.firstName} ${chat.messages[0].sender.lastName}`,
                senderEmail: chat.messages[0].sender.email,
            } : null,
        }));
        return res.json(formattedChats);
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.get('/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const chat = await Chat.findById(id)
            .populate('participants', 'firstName lastName email picture')
            .populate({
                path: 'messages.sender',
                select: 'firstName lastName picture email',
            })
            .lean();

        if (!chat) {
            return res.status(404).json({ message: 'Conversation non trouvée' });
        }

        chat.participants = chat.participants.map(participant => ({
            firstName: participant.firstName,
            lastName: participant.lastName,
            email: participant.email,
            picture: participant.picture,
        }));

        chat.messages = chat.messages.map(message => ({
            date: message.date,
            content: message.content,
            type: message.type,
            senderName: `${message.sender.firstName} ${message.sender.lastName}`,
            senderPicture: message.sender.picture,
            senderEmail: message.sender.email,
        }));

        return res.json(chat);
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.post('/:id/message', async (req, res) => {
    const { id } = req.params;
    const { type, content } = req.body;

    if (!type || !content) {
        return res.status(400).json({ message: 'Champ(s) manquants' });
    }

    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }
        const chat = await Chat.findById(id);
        if (!chat) {
            return res.status(404).json({ message: 'Conversation non trouvée' });
        }

        const newMessage = {
            date: new Date(),
            sender: user._id,
            type: type,
            content: content,
        };

        chat.messages.unshift(newMessage);
        await chat.save();

        return res.status(201).json(newMessage);
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.delete('/:id/participant', async (req, res) => {
    const { id } = req.params;
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Champ(s) manquants' });
    }

    try {
        const chat = await Chat.findById(id);
        if (!chat) {
            return res.status(404).json({ message: 'Conversation non trouvée' });
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'Participant non trouvé' });
        }

        const isMaster = chat.participants[0].toString() === req.user.id;
        if (!isMaster) {
            return res.status(403).json({ message: 'Vous n\'êtes pas autorisé à supprimer ce participant.' });
        }

        chat.participants = chat.participants.filter(participant => !participant.equals(user._id));
        await chat.save();

        return res.json({ message: 'Participant supprimé avec succès.' });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.post('/:id/participant', async (req, res) => {
    const { id } = req.params;
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Champ(s) manquants' });
    }

    try {
        const chat = await Chat.findById(id);
        if (!chat) {
            return res.status(404).json({ message: 'Conversation non trouvée' });
        }

        const user = await User.findOne({ email });
        if (!user) {
            return res.status(404).json({ message: 'Participant non trouvé' });
        }

        const isMaster = chat.participants[0].toString() === req.user.id;
        if (!isMaster) {
            return res.status(403).json({ message: 'Vous n\'êtes pas autorisé à ajouter ce participant.' });
        }

        if (chat.participants.includes(user._id)) {
            return res.status(400).json({ message: 'Participant déjà dans la conversation.' });
        }

        chat.participants.push(user._id);
        await chat.save();

        return res.json({ message: 'Participant ajouté avec succès.', chatId: chat._id });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.delete('/:id/leave', async (req, res) => {
    const { id } = req.params;

    try {
        const chat = await Chat.findById(id);
        if (!chat) {
            return res.status(404).json({ message: 'Conversation non trouvée' });
        }

        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        if (!chat.participants.includes(user._id)) {
            return res.status(400).json({ message: 'Vous n\'êtes pas un participant de cette conversation.' });
        }

        chat.participants = chat.participants.filter(participant => !participant.equals(user._id));

        if (chat.participants.length === 0) {
            await Chat.findByIdAndDelete(id);
            return res.json({ message: 'Conversation supprimée.' });
        }

        await chat.save();

        return res.json({ message: 'Vous avez quitté la conversation avec succès.' });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ message: 'Erreur serveur' });
    }
});


module.exports = router;

const express = require('express');
const User = require('./../models/User');
const router = express.Router();

router.get('/', async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password').populate('friends').populate('friendRequests');

        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        const friendsList = user.friends.map(friend => ({
            email: friend.email,
            firstName: friend.firstName,
            lastName: friend.lastName,
            picture: friend.picture,
        }));

        const friendRequestsList = user.friendRequests.map(request => ({
            email: request.email,
            firstName: request.firstName,
            lastName: request.lastName,
            picture: request.picture,
        }));

        return res.json({
            friends: friendsList,
            friendRequests: friendRequestsList,
        });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.get('/search', async (req, res) => {
    const { email } = req.query;

    if (!email) {
        return res.status(400).json({ message: 'Email requis' });
    }

    try {
        const user = await User.findById(req.user.id).select('-password').populate('friends').populate('friendRequests');
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        const friend = await User.findOne({ email }).select('-password');
        if (!friend) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        let canAdd = true;
        if (user._id.equals(friend._id)) {
            canAdd = false;
        }
        if (user.friends.some(f => f._id.equals(friend._id))) {
            canAdd = false;
        }
        if (friend.friendRequests.some(req => req._id.equals(user._id))) {
            canAdd = false;
        }
        if (user.friendRequests.some(req => req._id.equals(friend._id))) {
            canAdd = false;            
        }
        return res.json({
            user: {
                firstName: friend.firstName,
                lastName: friend.lastName,
                picture: friend.picture,
            },
            canAdd,
        });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.post('/request', async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Email requis' });
    }

    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        const friend = await User.findOne({ email }).select('-password');
        if (!friend) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        if (friend.friendRequests.some(req => req._id.equals(user._id))) {
            return res.status(400).json({ message: 'Demande déjà envoyée' });
        }
        if (friend.friends.some(req => req._id.equals(user._id))) {
            return res.status(400).json({ message: 'Déjà amis' });
        }
        if (user.friendRequests.some(req => req._id.equals(friend._id))) {
            user.friends.push(friend._id);
            friend.friends.push(user._id);
            user.friendRequests = user.friendRequests.filter(req => !req._id.equals(friend._id));
            await user.save();
            await friend.save();
            return res.status(200).json({ message: 'Demande d\'ami acceptée avec succès' });
        }

        friend.friendRequests.push(user._id);
        await friend.save();

        return res.status(200).json({ message: 'Demande d\'ami envoyée avec succès' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.post('/accept', async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Email requis' });
    }

    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        const friend = await User.findOne({ email }).select('-password');
        if (!friend) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        if (!user.friendRequests.some(req => req._id.equals(friend._id))) {
            return res.status(400).json({ message: 'Demande d\'ami non trouvée' });
        }

        user.friends.push(friend._id);
        friend.friends.push(user._id);

        user.friendRequests = user.friendRequests.filter(req => !req._id.equals(friend._id));
        friend.friendRequests = friend.friendRequests.filter(req => !req._id.equals(user._id));

        await user.save();
        await friend.save();

        return res.status(200).json({ message: 'Demande d\'ami acceptée avec succès' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.post('/reject', async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Email requis' });
    }

    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        const friend = await User.findOne({ email }).select('-password');
        if (!friend) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        if (!user.friendRequests.some(req => req._id.equals(friend._id))) {
            return res.status(400).json({ message: 'Demande d\'ami non trouvée' });
        }

        user.friendRequests = user.friendRequests.filter(req => !req._id.equals(friend._id));
        friend.friendRequests = friend.friendRequests.filter(req => !req._id.equals(user._id));

        await user.save();
        await friend.save();

        return res.status(200).json({ message: 'Demande d\'ami rejetée avec succès' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.delete('/unfriend', async (req, res) => {
    const { email } = req.body;

    if (!email) {
        return res.status(400).json({ message: 'Email requis' });
    }

    try {
        const user = await User.findById(req.user.id).select('-password');
        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        const friend = await User.findOne({ email }).select('-password');
        if (!friend) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        if (!user.friends.some(f => f._id.equals(friend._id))) {
            return res.status(400).json({ message: 'Pas d\'ami à supprimer' });
        }

        user.friends = user.friends.filter(f => !f._id.equals(friend._id));
        friend.friends = friend.friends.filter(f => !f._id.equals(user._id));

        await user.save();
        await friend.save();

        return res.status(200).json({ message: 'Ami supprimé avec succès' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

module.exports = router;

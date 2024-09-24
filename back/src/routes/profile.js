const express = require('express');
const User = require('./../models/User');
const multer = require('multer');
const path = require('path');
const router = express.Router();

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'public/uploads/profile-pictures');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ storage });


router.get('/', async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');

        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        res.json(user);
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

router.post('/edit-picture', upload.single('picture'), async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password');

        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        if (!req.file) {
            return res.status(400).json({ message: 'Aucun fichier envoyé' });
        }

        user.picture = `/uploads/profile-pictures/${req.file.filename}`;
        await user.save();

        res.json({ message: 'Photo de profil mise à jour', picture: user.picture });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
})

router.delete('/delete', async (req, res) => {
    try {
        const user = await User.findById(req.user.id);

        if (!user) {
            return res.status(404).json({ message: 'Utilisateur non trouvé' });
        }

        await User.findByIdAndDelete(req.user.id);
        res.json({ message: 'Profil supprimé avec succès' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});


module.exports = router;

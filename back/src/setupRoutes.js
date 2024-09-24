const authRoutes = require('./routes/auth');
const profileRoutes = require('./routes/profile');
const FriendsRoutes = require('./routes/friends');
const ChatRoutes = require('./routes/chat');
const auth = require('./middleware/auth');

const setupRoutes = (app) => {
    app.use('/auth', authRoutes);
    app.use('/profile', auth, profileRoutes);
    app.use('/friends', auth, FriendsRoutes);
    app.use('/chat', auth, ChatRoutes);
}

module.exports = setupRoutes;
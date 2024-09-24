const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
    participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    messages: [{
        date: { type: Date, required: true },
        sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        type: { type: String, required: true },
        content: { type: String, required: true },
    }],
    readBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
    group: { type: Boolean, required: true },
});

module.exports = mongoose.model('Chat', chatSchema);

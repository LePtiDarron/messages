const chatSockets = {};

module.exports = (io) => {
  io.of('/messages').on('connection', (socket) => {

    socket.on('enterChat', (chatId) => {
      chatSockets[socket.id] = { chatId };
    });

    socket.on('actuMessages', (data) => {
      const chatId = data.chatId;
      Object.keys(chatSockets).forEach((socketId) => {
        if (chatSockets[socketId].chatId === chatId) {
          io.of('/messages').to(socketId).emit('actuMessages', data);
        }
      });
    });

    socket.on('disconnect', () => {
      if (chatSockets[socket.id]) {
        delete chatSockets[socket.id];
      }
    });
  });
};

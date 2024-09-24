const userSockets = {};

module.exports = (io) => {
  io.of('/friends').on('connection', (socket) => {

    socket.on('register', (email) => {
      userSockets[socket.id] = { email };
    });

    socket.on('actuFriends', (data) => {
      const emails = data.emails;
      Object.keys(userSockets).forEach((socketId) => {
        if (emails.includes(userSockets[socketId].email)) {
          io.of('/friends').to(socketId).emit('actuFriends', data);
        }
      });
    });

    socket.on('disconnect', () => {
      if (userSockets[socket.id]) {
        const userEmail = userSockets[socket.id].email;
        delete userSockets[socket.id];
      }
    });
  });
};

const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const setupRoutes = require('./setupRoutes');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.use('/uploads', express.static('public/uploads'));
app.use(express.json());
app.use(cors({
    origin: 'http://localhost:3000',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    credentials: true
}));

mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => console.log("Connected to the DB"))
    .catch((err) => console.log(err));

setupRoutes(app);
require('./friendsSocket')(io);
require('./messagesSocket')(io);

const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}/`);
});

import express from "express";
import mongoose from "mongoose";
import authRouter from "./routes/auth.js";
import cors from "cors";
import dotenv from "dotenv";
import documentRouter from "./routes/document.js";
import http from "http";
import Server from "socket.io";
import Document from "./models/document.js";
const app = express();

var server = http.createServer(app);
var io = new Server(server);
app.use(cors());

dotenv.config();
const PORT = process.env.PORT | 3001;

const DB = process.env.MONGO_CONFIG;

app.use(express.json());
app.use(authRouter);
app.use(documentRouter);
mongoose
  .connect(DB)
  .then(() => {
    console.log("Connection successful");
  })
  .catch((err) => {
    console.log(err);
  });

io.on("connection", (socket) => {
  socket.on("join", (documentId) => {
    socket.join(documentId);
    console.log("joined!");
  });
  socket.on("typing", (data) => {
    socket.broadcast.to(data.room).emit("changes", data);
  });

  socket.on("save", (data) => {
    saveData(data);
  });
});
const saveData = async (data) => {
  let document = await Document.findById(data.room);
  document.content = data.delta;
  document = await document.save();
};

server.listen(PORT, "0.0.0.0", () => {
  console.log(`connected at port ${PORT}`);
});

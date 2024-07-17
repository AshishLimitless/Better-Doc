import express from "express";
import User from "../models/user.js";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import auth from "../middlewares/auth.js";

const authRouter = express.Router();
dotenv.config();

authRouter.post("/api/signup", async (req, res) => {
  try {
    const { name, email, profilePic } = req.body;

    let user = await User.findOne({ email: email }); // Use await here

    if (!user) {
      user = new User({
        email: email,
        name: name,
        profilePic: profilePic,
      });
      user = await user.save();
    }
    //console.log(process.env.SECRET_PASSKEY);
    const token = jwt.sign({ id: user._id }, process.env.SECRET_PASSKEY);

    res.status(201).json({ user, token });
  } catch (err) {
    console.log(err);
    res.status(500).json({ message: "Internal server error" });
  }
});

authRouter.get("/", auth, async (req, res) => {
  try {
    // console.log("ksdhskj");
    const user = await User.findById(req.user);
    res.json({ user, token: req.token });
  } catch (e) {
    res.status(500).json({ message: "Getting user details failed.." });
  }
});

export default authRouter;

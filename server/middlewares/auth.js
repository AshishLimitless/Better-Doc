import jwt from "jsonwebtoken";
import dotenv from "dotenv";
dotenv.config();
const auth = async (req, res, next) => {
  try {
    const token = req.header("x-auth-token");
    if (!token) {
      return res.status(401).json({ error: "No auth token , access denied" });
    }
    const verified = jwt.verify(token, process.env.SECRET_PASSKEY);
    if (!verified)
      return res.status(401).json({ error: "authorization denied" });
    req.user = verified.id;
    req.token = token;
    next();
  } catch (e) {
    // console.log("ahaak");
    // console.log(e);
    res.status(500).json({ error: e.message });
  }
  // next();
};

export default auth;

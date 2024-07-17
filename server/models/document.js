//what should be there
import mongoose, { mongo } from "mongoose";
// 1) user id
// 2) creation time
// 3) title
// 4) contents

const documentSchema = mongoose.Schema({
  uid: {
    required: true,
    type: String,
  },
  createdAt: {
    required: true,
    type: Number,
  },
  title: {
    required: true,
    type: String,
    trim: true,
  },
  contents: {
    type: Array,
    default: [],
  },
});

const Document = mongoose.model("Document", documentSchema);
export default Document;

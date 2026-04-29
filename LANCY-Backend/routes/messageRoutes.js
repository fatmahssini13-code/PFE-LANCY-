const express = require("express");
const router = express.Router();
const Message = require("../models/message");

// ➜ GET messages (chat history)
router.get("/:projectId", async (req, res) => {
  try {
    const messages = await Message.find({
      projectId: req.params.projectId,
    }).sort({ createdAt: 1 });

    res.status(200).json(messages);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ➜ POST message (REST fallback)
router.post("/", async (req, res) => {
  try {
    const { projectId, senderId, receiverId, text } = req.body;

    const message = new Message({
      projectId,
      senderId,
      receiverId,
      text,
    });

    await message.save();

    res.status(201).json(message);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
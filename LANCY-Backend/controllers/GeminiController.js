const express = require("express");
const axios = require("axios");

const router = express.Router();

router.post("/chat-gemini", async (req, res) => {
  const message = req.body.message;

  try {
    const response = await axios.post(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=YOUR_API_KEY",
      {
        contents: [
          {
            parts: [{ text: message }]
          }
        ]
      }
    );

    const reply =
      response.data.candidates?.[0]?.content?.parts?.[0]?.text ||
      "pas de réponse IA";

    res.json({ reply });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
import { createServer } from "node:http";
import handler from "../api/gym.js";
const server = createServer(async (req, res) => {
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (value) => {
    res.setHeader("Content-Type", "application/json");
    res.end(JSON.stringify(value));
  };
  if (req.url !== "/api/gym") {
    res.statusCode = 404;
    res.end("Not found");
    return;
  }
  let bytes = 0,
    chunks = [];
  for await (const chunk of req) {
    bytes += chunk.length;
    if (bytes > 3 * 1024 * 1024) {
      res.status(413).json({ error: "Request too large." });
      return;
    }
    chunks.push(chunk);
  }
  req.body = Buffer.concat(chunks).toString();
  await handler(req, res);
});
server.listen(Number(process.env.PORT ?? 3000), "0.0.0.0", () =>
  console.log("FitGuide API listening on port " + (process.env.PORT ?? 3000)),
);

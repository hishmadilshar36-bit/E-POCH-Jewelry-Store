import { app } from "./app";
import { env } from "./config/env";
import { startTryOnWorker } from "./services/ai/tryon.worker";

app.listen(env.port, "0.0.0.0", () => console.log(`API on :${env.port}`));
startTryOnWorker();

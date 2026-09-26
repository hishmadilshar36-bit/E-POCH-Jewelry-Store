import { app } from "./app";
import { env } from "./config/env";
import { startTryOnWorker } from "./services/ai/tryon.worker";

app.listen(env.port, () => console.log(`API on :${env.port}`));
startTryOnWorker();
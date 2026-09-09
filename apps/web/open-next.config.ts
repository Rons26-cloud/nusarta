import { defineCloudflareConfig } from "@opennextjs/cloudflare/config";

// Release pages are dynamic and use a bounded GitHub catalog Cache API cache.
// No Next.js ISR bucket or queue is required.
export default defineCloudflareConfig();

import { defineCloudflareConfig } from "@opennextjs/cloudflare/config";

// No ISR or on-demand revalidation is used; no cache bucket is required.
export default defineCloudflareConfig();

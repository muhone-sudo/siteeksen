import apiClient from "./api-client";
import { endpoints } from "./endpoints";

/** Sayfaların kullandığı tek API nesnesi (uçlar: lib/endpoints.ts). */
export const api = endpoints(apiClient);
export default api;

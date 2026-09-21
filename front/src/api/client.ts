import axios from "axios";
import { getEnv } from "@/utils/env";

export const client = axios.create({
  headers: { "Content-Type": "application/json" },
});

client.interceptors.request.use((config) => {
  config.baseURL = getEnv("VITE_API_URL");
  return config;
});

import { client } from "./client";
import type {
  Title,
  TitleFilter,
  CreateTitlePayload,
  UpdateTitlePayload,
} from "@/features/titles/types";

export async function listTitles(
  filter: TitleFilter,
): Promise<{ titles: Title[] }> {
  const params: Record<string, string> = {};
  if (filter.name) params["name"] = filter.name;
  if (filter.type) params["type"] = filter.type;

  const { data } = await client.get<{ titles: Title[] }>("v1/titles", {
    params,
  });
  return data;
}

export async function createTitle(
  payload: CreateTitlePayload,
): Promise<{ data: Title }> {
  const { data } = await client.post<{ data: Title }>("v1/titles", payload);
  return data;
}

export async function deleteTitle(id: string): Promise<void> {
  await client.delete(`v1/titles/${id}`);
}

export async function updateTitle(
  id: string,
  payload: UpdateTitlePayload,
): Promise<{ data: Title }> {
  const { data } = await client.patch<{ data: Title }>(
    `v1/titles/${id}`,
    payload,
  );
  return data;
}

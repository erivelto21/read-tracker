export const TITLE_TYPES = [
  "book",
  "manga",
  "manhua",
  "novel",
  "article",
] as const;
export type TitleType = (typeof TITLE_TYPES)[number];

export interface Title {
  id: string;
  name: string;
  type: TitleType;
  chapter?: number;
  page?: number;
  link?: string;
  observation?: string;
}

export interface TitleFilter {
  name?: string;
  type?: TitleType | "";
}

export interface CreateTitlePayload {
  name: string;
  type: TitleType;
  chapter?: number;
  page?: number;
  link?: string;
  observation?: string;
}

export interface UpdateTitlePayload {
  chapter?: number;
  page?: number;
  link?: string;
  observation?: string;
}

import type { TitleFilter } from "@/features/titles/types";

export const queryKeys = {
  titles: {
    all: () => ["titles"] as const,
    list: (filter: TitleFilter) => ["titles", "list", filter] as const,
  },
} as const;

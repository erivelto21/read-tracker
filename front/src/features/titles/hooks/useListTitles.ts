import { useQuery } from "@tanstack/react-query";
import { listTitles } from "@/api/titles";
import { queryKeys } from "@/lib/queryKeys";
import { useDebounce } from "@/hooks/useDebounce";
import type { TitleFilter } from "@/features/titles/types";

export function useListTitles(filter: TitleFilter) {
  const debouncedName = useDebounce(filter.name ?? "", 300);

  const debouncedFilter: TitleFilter = {
    name: debouncedName,
    type: filter.type,
  };

  return useQuery({
    queryKey: queryKeys.titles.list(debouncedFilter),
    queryFn: () => listTitles(debouncedFilter),
  });
}

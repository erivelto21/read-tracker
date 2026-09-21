import { useState } from "react";
import { TITLE_TYPES } from "@/features/titles/types";
import type { TitleType } from "@/features/titles/types";
import { useListTitles } from "@/features/titles/hooks/useListTitles";
import { TitleTable } from "@/features/titles/components/TitleTable";
import { SegmentedControl } from "@/components/SegmentedControl";
import { CreateTitleModal } from "@/features/titles/components/CreateTitleModal";

type TypeOption = TitleType | "";

const TYPE_OPTIONS: { value: TypeOption; label: string }[] = [
  { value: "", label: "All types" },
  ...TITLE_TYPES.map((t) => ({
    value: t,
    label: t.charAt(0).toUpperCase() + t.slice(1),
  })),
];

export function TitlesPage(): React.JSX.Element {
  const [name, setName] = useState("");
  const [type, setType] = useState<TypeOption>("");
  const [isModalOpen, setIsModalOpen] = useState(false);

  const { data, isLoading, isError } = useListTitles({ name, type });

  function handleRowClick(id: string): void {
    // TODO: navigate to detail/edit view for title with `id`
    void id;
  }

  return (
    <div className="min-h-screen bg-sky-50 p-6" data-testid="titles-page">
      <div className="max-w-5xl mx-auto space-y-4">
        <h1 className="text-2xl font-bold text-gray-900">Reading List</h1>

        {/* Filter card */}
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-4 flex flex-wrap gap-4 items-center">
          <input
            data-testid="title-name-filter"
            type="text"
            value={name}
            onChange={(e) => {
              setName(e.target.value);
            }}
            placeholder="Filter by name…"
            className="flex-1 min-w-48 rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-sky-400 focus:bg-white transition-colors"
          />
          <SegmentedControl
            data-testid="title-type-filter"
            options={TYPE_OPTIONS}
            value={type}
            onChange={setType}
          />
        </div>

        {/* Table card */}
        {isLoading && (
          <p
            data-testid="titles-loading"
            className="text-center text-gray-500 py-8"
          >
            Loading titles…
          </p>
        )}

        {isError && (
          <p
            data-testid="titles-error"
            className="text-center text-red-600 bg-red-50 border border-red-200 rounded-xl py-4 px-6"
          >
            Failed to load titles. Please try again.
          </p>
        )}

        {!isLoading && !isError && (
          <TitleTable
            titles={data?.titles ?? []}
            onRowClick={handleRowClick}
            onAddClick={() => {
              setIsModalOpen(true);
            }}
          />
        )}

        {isModalOpen && (
          <CreateTitleModal
            onClose={() => {
              setIsModalOpen(false);
            }}
          />
        )}
      </div>
    </div>
  );
}

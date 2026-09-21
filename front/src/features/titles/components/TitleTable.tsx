import { useState } from "react";
import type { Title } from "@/features/titles/types";
import { TitleRow } from "./TitleRow";
import { EditTitleModal } from "./EditTitleModal";
import { useDeleteTitle } from "@/features/titles/hooks/useDeleteTitle";

interface TitleTableProps {
  titles: Title[];
  onRowClick?: (id: string) => void;
  onAddClick?: () => void;
}

export function TitleTable({
  titles,
  onRowClick,
  onAddClick,
}: TitleTableProps): React.JSX.Element {
  const {
    mutate: deleteTitle,
    isPending: isDeleting,
    variables: deletingId,
  } = useDeleteTitle();
  const [editingTitle, setEditingTitle] = useState<Title | null>(null);

  return (
    <>
      <div
        data-testid="title-table"
        className="rounded-xl overflow-hidden border border-gray-200 shadow-sm bg-white"
      >
        {/* Table toolbar */}
        <div className="flex items-center justify-between px-4 py-3 border-b border-gray-200 bg-[#f0f0f0]">
          <span className="text-sm font-semibold text-gray-600 uppercase tracking-wide">
            Titles
          </span>
          <button
            type="button"
            data-testid="add-title-btn"
            onClick={onAddClick}
            className="inline-flex items-center gap-1.5 rounded-lg bg-sky-500 px-3 py-1.5 text-sm font-medium text-white shadow-sm hover:bg-sky-600 transition-colors focus:outline-none focus:ring-2 focus:ring-sky-400"
          >
            <span aria-hidden="true">+</span>
            Add Title
          </button>
        </div>

        <table className="w-full text-sm">
          <thead>
            <tr className="bg-[#f0f0f0] text-gray-600 border-b border-gray-200">
              <th className="px-4 py-2.5 text-left font-semibold">Name</th>
              <th className="px-4 py-2.5 text-left font-semibold">Type</th>
              <th className="px-4 py-2.5 text-right font-semibold">Progress</th>
              <th className="px-3 py-2.5 text-left font-semibold w-28">
                Status
              </th>
              <th className="px-3 py-2.5 w-20" aria-label="Actions" />
            </tr>
          </thead>
          <tbody data-testid="title-list-items">
            {titles.length === 0 ? (
              <tr>
                <td
                  colSpan={5}
                  className="px-4 py-8 text-center text-gray-400"
                  data-testid="title-table-empty"
                >
                  No titles found.
                </td>
              </tr>
            ) : (
              titles.map((title, index) => (
                <TitleRow
                  key={title.id}
                  title={title}
                  index={index}
                  onClick={onRowClick}
                  onDelete={(id) => {
                    deleteTitle(id);
                  }}
                  onEdit={(t) => {
                    setEditingTitle(t);
                  }}
                  isDeleting={isDeleting && deletingId === title.id}
                />
              ))
            )}
          </tbody>
        </table>
      </div>

      {editingTitle && (
        <EditTitleModal
          title={editingTitle}
          onClose={() => {
            setEditingTitle(null);
          }}
        />
      )}
    </>
  );
}

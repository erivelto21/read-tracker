import { useState } from "react";
import type { Title } from "@/features/titles/types";
import { ConfirmDialog } from "./ConfirmDialog";

interface TitleRowProps {
  title: Title;
  index: number;
  onClick?: (id: string) => void;
  onDelete?: (id: string) => void;
  onEdit?: (title: Title) => void;
  isDeleting?: boolean;
}

function formatProgress(chapter?: number, page?: number): string {
  if (chapter !== undefined && page !== undefined)
    return `Ch. ${String(chapter)}, P. ${String(page)}`;
  if (chapter !== undefined) return `Ch. ${String(chapter)}`;
  if (page !== undefined) return `P. ${String(page)}`;
  return "—";
}

export function TitleRow({
  title,
  index,
  onClick,
  onDelete,
  onEdit,
  isDeleting = false,
}: TitleRowProps): React.JSX.Element {
  const isEven = index % 2 === 0;
  const [showConfirm, setShowConfirm] = useState(false);

  return (
    <>
      <tr
        data-testid="title-row"
        onClick={() => {
          onClick?.(title.id);
        }}
        className={`group
          ${isEven ? "bg-white" : "bg-gray-50/60"}
          hover:bg-sky-50 transition-colors
          ${onClick ? "cursor-pointer" : ""}
        `}
      >
        <td className="px-4 py-3 text-gray-900 font-medium">{title.name}</td>
        <td className="px-4 py-3 text-gray-600 capitalize">{title.type}</td>
        <td className="px-4 py-3 text-gray-600 text-right tabular-nums">
          {formatProgress(title.chapter, title.page)}
        </td>
        <td className="px-3 py-3 w-28">
          <span className="inline-flex items-center rounded-full bg-green-100 px-2.5 py-0.5 text-xs font-medium text-green-800">
            Reading
          </span>
        </td>
        {(onEdit ?? onDelete) && (
          <td className="px-3 py-3 w-20">
            <div className="flex items-center gap-1">
              {onEdit && (
                <button
                  type="button"
                  aria-label={`Edit ${title.name}`}
                  onClick={(e) => {
                    e.stopPropagation();
                    onEdit(title);
                  }}
                  className="opacity-0 group-hover:opacity-100 transition-opacity rounded p-1 text-gray-400 hover:text-sky-600 hover:bg-sky-50"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-4 w-4"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
                  </svg>
                </button>
              )}
              {onDelete && (
                <button
                  type="button"
                  aria-label={`Delete ${title.name}`}
                  onClick={(e) => {
                    e.stopPropagation();
                    setShowConfirm(true);
                  }}
                  className="opacity-0 group-hover:opacity-100 transition-opacity rounded p-1 text-gray-400 hover:text-red-600 hover:bg-red-50"
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-4 w-4"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fillRule="evenodd"
                      d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                      clipRule="evenodd"
                    />
                  </svg>
                </button>
              )}
            </div>
          </td>
        )}
      </tr>

      {showConfirm && (
        <ConfirmDialog
          titleName={title.name}
          isPending={isDeleting}
          onCancel={() => {
            setShowConfirm(false);
          }}
          onConfirm={() => {
            onDelete?.(title.id);
            setShowConfirm(false);
          }}
        />
      )}
    </>
  );
}

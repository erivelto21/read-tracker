import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";
import { describe, it, expect, beforeAll, afterAll, afterEach } from "vitest";
import { screen, waitFor } from "@testing-library/react";
import { TitlesPage } from "@/pages/TitlesPage";
import { renderWithProviders } from "@/utils/test-utils";
import type { Title } from "@/features/titles/types";

const mockTitles: Title[] = [
  { id: "1", name: "One Piece", type: "manga", chapter: 1100 },
  { id: "2", name: "Dune", type: "book", chapter: 1, page: 412 },
];

const server = setupServer(
  http.get("*/titles", () => {
    return HttpResponse.json({ titles: mockTitles });
  }),
);

beforeAll(() => {
  server.listen();
});
afterEach(() => {
  server.resetHandlers();
});
afterAll(() => {
  server.close();
});

describe("TitlesPage", () => {
  it("renders the page title", () => {
    renderWithProviders(<TitlesPage />);
    expect(screen.getByText("Reading List")).toBeInTheDocument();
  });

  it("shows loading state initially", () => {
    renderWithProviders(<TitlesPage />);
    expect(screen.getByTestId("titles-loading")).toBeInTheDocument();
  });

  it("renders titles in the table after loading", async () => {
    renderWithProviders(<TitlesPage />);

    await waitFor(() => {
      expect(screen.getByText("One Piece")).toBeInTheDocument();
    });
    expect(screen.getByText("Dune")).toBeInTheDocument();
  });

  it("shows error state when API fails", async () => {
    server.use(
      http.get("*/titles", () => {
        return new HttpResponse(null, { status: 500 });
      }),
    );

    renderWithProviders(<TitlesPage />);

    await waitFor(() => {
      expect(screen.getByTestId("titles-error")).toBeInTheDocument();
    });
  });

  it("renders name filter input and type select", () => {
    renderWithProviders(<TitlesPage />);
    expect(screen.getByTestId("title-name-filter")).toBeInTheDocument();
    expect(screen.getByTestId("title-type-filter")).toBeInTheDocument();
  });
});

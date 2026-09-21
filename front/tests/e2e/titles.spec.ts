import { test, expect } from "@playwright/test";

test("titles page shows Reading List heading", async ({ page }) => {
  await page.goto("/titles");
  await expect(page.getByText("Reading List")).toBeVisible();
});

test("filter bar renders name input and type segmented control", async ({
  page,
}) => {
  await page.goto("/titles");
  await expect(page.getByTestId("title-name-filter")).toBeVisible();
  await expect(page.getByTestId("title-type-filter")).toBeVisible();
});

test("Add Title button is visible in the table card", async ({ page }) => {
  await page.goto("/titles");
  await expect(page.getByTestId("add-title-btn")).toBeVisible();
});

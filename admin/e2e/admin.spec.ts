import { test, expect } from "@playwright/test";
test("all modules render honest setup states", async ({ page }) => {
  for (const slug of [
    "dashboard",
    "reports",
    "levels",
    "roads",
    "alerts",
    "cctv",
    "users",
    "emergency",
    "analytics",
    "settings",
  ]) {
    await page.goto("/admin/" + slug);
    await expect(
      page.getByText("Database not connected.", { exact: false }),
    ).toBeVisible();
    await expect(page.locator("h1")).toBeVisible();
    await expect(page.getByText("Application error")).toHaveCount(0);
  }
  await page.goto("/admin/analytics?tab=audit");
  await expect(
    page.getByRole("heading", { name: "Audit Logs", exact: true }),
  ).toBeVisible();
  await page.goto("/admin/settings");
  await expect(page.getByRole("heading", { name: /Audit/ })).toHaveCount(0);
  await page.goto("/admin/emergency?tab=centers");
  await expect(
    page.getByRole("columnheader", { name: "Last verified" }),
  ).toBeVisible();
});
test("login cannot simulate an administrator without configuration", async ({
  page,
}) => {
  await page.goto("/login");
  await page.getByLabel("Email address").fill("test@example.com");
  await page.getByLabel("Password", { exact: true }).fill("test-only-password");
  await page.getByRole("button", { name: "Show password" }).click();
  await expect(page.getByLabel("Password", { exact: true })).toHaveAttribute(
    "type",
    "text",
  );
  await page.getByRole("button", { name: "Sign in" }).click();
  await expect(page.locator("p[role=alert]")).toContainText(
    "Supabase is not configured",
  );
  await expect(page).toHaveURL(/login/);
});
test("tablet layout fits and sidebar collapses", async ({ page }) => {
  await page.setViewportSize({ width: 768, height: 1024 });
  await page.goto("/admin/dashboard");
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBeTruthy();
  await page.getByRole("button", { name: "Toggle sidebar" }).click();
  await expect(page.locator(".app")).toHaveClass("app collapsed");
  await page.screenshot({
    path: "artifacts/dashboard-tablet.png",
    fullPage: true,
  });
});

test("desktop overview and login render without horizontal overflow", async ({
  page,
}) => {
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto("/admin/dashboard");
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBeTruthy();
  await page.screenshot({
    path: "artifacts/dashboard-desktop.png",
    fullPage: true,
  });
  await page.goto("/login");
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBeTruthy();
  await page.screenshot({
    path: "artifacts/login-desktop.png",
    fullPage: true,
  });
});

const test = require("node:test");
const assert = require("node:assert");
const { slugify } = require("./slugify");

test("spaces become dashes", () => {
  assert.strictEqual(slugify("Hello World"), "hello-world");
});

test("repeated spaces collapse into one dash", () => {
  assert.strictEqual(slugify("Hello   World"), "hello-world");
});

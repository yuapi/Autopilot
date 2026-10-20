// Turn a title into a URL slug: "Hello World" -> "hello-world"
function slugify(title) {
  return title.toLowerCase().split(" ").join("-");
}
module.exports = { slugify };

module.exports = function (eleventyConfig) {
  eleventyConfig.addWatchTarget("src/html/");

  // Keep /html/Starter/home.html instead of /html/Starter/home/index.html
  eleventyConfig.addGlobalData("permalink", () => {
    return (data) => `${data.page.filePathStem}.html`;
  });

  return {
    htmlTemplateEngine: "njk",
    markdownTemplateEngine: "njk",
    templateFormats: ["html", "njk"],
    dir: {
      input: "src/html",
      includes: "components",
      output: "_site"
    }
  };
};


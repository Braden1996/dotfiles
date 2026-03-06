const { createRequire } = require("node:module");

const requireFromWorkspace = createRequire(`${process.cwd()}/package.json`);
const { createProjectGraphAsync, readProjectsConfigurationFromProjectGraph } = requireFromWorkspace("nx/src/devkit-exports");

(async () => {
  const graph = await createProjectGraphAsync();
  const projects = readProjectsConfigurationFromProjectGraph(graph).projects;
  const result = Object.fromEntries(
    Object.entries(projects)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([name, config]) => [
        name,
        Object.keys(config.targets || {}).sort((left, right) => left.localeCompare(right)),
      ])
  );

  process.stdout.write(JSON.stringify(result));
})().catch((error) => {
  console.error(error);
  process.exit(1);
});

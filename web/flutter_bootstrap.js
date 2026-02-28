{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      // Use the HTML renderer to avoid the CanvasKit WebGL context-loss bug
      // ("LateInitializationError: Field '_handledContextLostEvent'").
      renderer: "html",
    });
    await appRunner.runApp();
  },
});

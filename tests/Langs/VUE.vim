vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class VUE extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "vue-ls",
      filetype: ["vue"],
      path: "vue-language-server",
      args: ["--stdio"],
      initializationOptions: {
          typescript: {
              tsdk: "/usr/local/lib/node_modules/typescript/lib"
          },
          vue: {
            hybridMode: false
          }
       },
      workspaceConfig: {
        html: {
          format: {
	          enable: true,
	          wrapAttributes: "force-aligned"
          }
        }
      }
    }
  enddef

  def PreFormatString(): string
    return "<style>\n.text {}\n\n</style>\n<template>\n<div :style=\"\" :class=\"\">\n</div>\n</template>"
  enddef

  def PostFormatString(): string
    return "<style>\n.text {}\n</style>\n<template>\n\t<div :style=\"\"\n\t     :class=\"\">\n\t</div>\n</template>"
  enddef

  def CompletionStates(): list<tuple<string, list<string>>>
    return [
      ("<script setup>\nconst testVar = ref();\n</script>\n<template>\n<div :class=\"testV¤\">\n</div>\n</template>", ["testVar", "testVar"]),
      ("<templ¤", ["template", "template lang=\"pug\""]),
    ]
  enddef

  def CompletionAccepts(): list<tuple<string, string, string>>
    return [
      ("<script setup>\nconst value = ref();\nvalue.va¤\n</script>", "value", "<script setup>\nconst value = ref();\nvalue.value\n</script>\n"),
      ("<style>\n.item {\n\tdis¤\n}\n</style>\n", "display", "<style>\n.item {\n\tdisplay: $0;\n}\n</style>\n"),
      ("<script setup>\nconst testVar = ref(\"\")\n</script>\n<template>\n<div :class=\"tes¤\">\n</div></template>\n", 
      "testVar", 
      "<script setup>\nconst testVar = ref(\"\")\n</script>\n<template>\n<div :class=\"testVar\">\n</div></template>\n"),
      ("<script setup>\nconst testVar = ref(\"\")\n</script>\n<template>\n<div :class=\"!tes¤\">\n</div></template>\n", 
      "testVar", 
      "<script setup>\nconst testVar = ref(\"\")\n</script>\n<template>\n<div :class=\"!testVar\">\n</div></template>\n"),
      ("<template>\n<div :cl¤>\n</div>\n</template>\n", "class", "<template>\n<div class=\"$1\">\n</div>\n</template>\n"),
      ("<template>\n\ttexta¤\n</template>\n", "textarea", "<template>\n\t<textarea name=\"\${2}\" id=\"\${4}\">\${0}</textarea>\n</template>\n"),
    ]
  enddef

  def CompletionIncrEdit(): list<tuple<string, string, list<list<string>>>>
    return []
  enddef

endclass

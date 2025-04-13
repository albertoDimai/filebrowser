<template>
  <div id="editor-container" @wheel.prevent.stop>
    <header-bar>
      <action icon="close" :label="t('buttons.close')" @action="close()" />
      <title>{{ fileStore.req?.name ?? "" }}</title>

      <action
        v-if="authStore.user?.perm.modify && !isMauroOutputFile"
        id="save-button"
        icon="save"
        :label="t('buttons.save')"
        @action="save()"
      />

      <button class="action">
      <a v-if="isMauroM2hvFile"
         target="_blank"
         :href="rawMauroFile"
      > <i class="material-icons">open_in_browser</i> </a>
      </button>

      <action
        icon="preview"
        :label="t('buttons.preview')"
        @action="preview()"
        v-show="isMarkdownFile"
      />
    </header-bar>

    <Breadcrumbs base="/files" noLink />

    <!-- preview container -->
    <div
      v-show="isPreview && isMarkdownFile"
      id="preview-container"
      class="md_preview"
      v-html="previewContent"
    ></div>

    <form v-show="!isPreview || !isMarkdownFile" id="editor"></form>
  </div>
</template>

<script setup lang="ts">
import { files as api } from "@/api";
import buttons from "@/utils/buttons";
import url from "@/utils/url";
import ace, { Ace, version as ace_version } from "ace-builds";
import modelist from "ace-builds/src-noconflict/ext-modelist";
import "ace-builds/src-noconflict/ext-language_tools";

import HeaderBar from "@/components/header/HeaderBar.vue";
import Action from "@/components/header/Action.vue";
import Breadcrumbs from "@/components/Breadcrumbs.vue";
import { useAuthStore } from "@/stores/auth";
import { useFileStore } from "@/stores/file";
import { useLayoutStore } from "@/stores/layout";
import { inject, onBeforeUnmount, onMounted, ref, watchEffect } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useI18n } from "vue-i18n";
import { getTheme } from "@/utils/theme";
import { marked } from "marked";

const $showError = inject<IToastError>("$showError")!;

const fileStore = useFileStore();
const authStore = useAuthStore();
const layoutStore = useLayoutStore();

const { t } = useI18n();

const route = useRoute();
const router = useRouter();

const editor = ref<Ace.Editor | null>(null);

//const rawContentLink = ref(null);

const isPreview = ref(false);
const previewContent = ref("");
const isMarkdownFile =
  fileStore.req?.name.endsWith(".md") ||
  fileStore.req?.name.endsWith(".markdown");

const isMauroOutputFile = isMauroOutFile(fileStore.req!.name);
const isMauroM2hvFile = isMauroM2HVOutFile(fileStore.req!.name);

const rawMauroFile = createRawMauroFile(fileStore.req!.url)

function createRawMauroFile(path : string) {
  //in      /files/gg_m2hv/m2hv.OUT.log
  //out    /api/raw-inline/gg_m2hv/m2hv.OUT.log
  return path.replace("/files/", "/api/raw-inline/").replace( "m2hv.OUT.log","index.html");
}

function isMauroOutFile(filename : string) {
   return filename.match('^(m2lv|m2hv|m2ledmac|pdflatex)\\.OUT\\.log$')
}

function isMauroM2HVOutFile(filename : string) {
  return isMauroOutFile(filename) && filename.startsWith('m2hv');
}

onMounted(() => {
  window.addEventListener("keydown", keyEvent);
  window.addEventListener("wheel", handleScroll);

  const fileContent = fileStore.req?.content || "";

  watchEffect(async () => {
    if (isMarkdownFile && isPreview.value) {
      const new_value = editor.value?.getValue() || "";
      try {
        previewContent.value = await marked(new_value);
      } catch (error) {
        console.error("Failed to convert content to HTML:", error);
        previewContent.value = "";
      }

      const previewContainer = document.getElementById("preview-container");
      if (previewContainer) {
        previewContainer.addEventListener("wheel", handleScroll, {
          capture: true,
        });
      }
    }
  });

  ace.config.set(
    "basePath",
    `https://cdn.jsdelivr.net/npm/ace-builds@${ace_version}/src-min-noconflict/`
  );

  editor.value = ace.edit("editor", {
    value: fileContent,
    showPrintMargin: false,
    readOnly: fileStore.req?.type === "textImmutable" || isMauroOutFile(fileStore.req!.name),

    theme: "ace/theme/terminal",
    // theme: "ace/theme/chrome",

    mode: modelist.getModeForPath(fileStore.req!.name).mode,
    wrap: true,

    enableBasicAutocompletion: false,
    enableLiveAutocompletion: false,
    enableSnippets: true,

    behavioursEnabled: false,
    fontSize: "16px"

  });

  if (getTheme() === "dark") {
    editor.value!.setTheme("ace/theme/twilight");
  }

  editor.value.focus();
});

onBeforeUnmount(() => {
  window.removeEventListener("keydown", keyEvent);
  window.removeEventListener("wheel", handleScroll);
  editor.value?.destroy();
});

const keyEvent = (event: KeyboardEvent) => {
  if (event.code === "Escape") {
    close();
  }

  if (!event.ctrlKey && !event.metaKey) {
    return;
  }

  if (event.key !== "s") {
    return;
  }

  event.preventDefault();
  save();
};

const handleScroll = (event: WheelEvent) => {
  const editorContainer = document.getElementById("preview-container");
  if (editorContainer) {
    editorContainer.scrollTop += event.deltaY;
  }
};

const save = async () => {
  const button = "save";
  buttons.loading("save");

  try {
    await api.put(route.path, editor.value?.getValue());
    editor.value?.session.getUndoManager().markClean();
    buttons.success(button);
  } catch (e: any) {
    buttons.done(button);
    $showError(e);
  }
};
const close = () => {
  if (!editor.value?.session.getUndoManager().isClean()) {
    layoutStore.showHover("discardEditorChanges");
    return;
  }

  fileStore.updateRequest(null);

  const uri = url.removeLastDir(route.path) + "/";
  router.push({ path: uri });
};

const preview = () => {
  isPreview.value = !isPreview.value;
};
</script>

<template>
  <div id="editor-container" @wheel.prevent.stop>
    <header-bar>
      <action icon="close" :label="t('buttons.close')" @action="close()" />
      <title>{{ fileStore.req?.name ?? "" }}</title>

      <!--      <action-->
      <!--        v-if="!readonly"-->
      <!--        id="help-button"-->
      <!--        icon="help"-->
      <!--        :label="t('buttons.help')"-->
      <!--        @action="editorHelp()"-->
      <!--      />-->

      <action
        v-if="!readonly"
        id="help-button"
        icon="search"
        :label="t('buttons.search')"
        @action="editorSearch()"
      />

      <action
        v-if="!readonly"
        id="help-button"
        icon="find_replace"
        :label="t('buttons.replace')"
        @action="editorReplace()"
      />

      <action
        v-if="!readonly"
        id="help-button"
        icon="settings"
        :label="t('buttons.settings')"
        @action="editorSettings()"
      />

      <action
        v-if="!readonly"
        id="help-button"
        icon="keyboard"
        :label="t('buttons.keybindings')"
        @action="editorKeybindings()"
      />

      <div style="width: 10px; height: 10px"></div>

      <i
        v-if="!readonly"
        class="autosave-label material-icons"
        style="visibility: hidden; opacity: 0; font-size: 90%; cursor: help"
      >
        published_with_changes
      </i>
      <action
        v-if="!readonly"
        id="save-button"
        icon="save"
        :label="t('buttons.save')"
        @action="save()"
      />

      <button class="action">
        <a v-if="isMauroM2hvFile" target="_blank" :href="rawMauroFile">
          <i class="material-icons">open_in_browser</i>
        </a>
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
const readonly =
  !authStore.user?.perm.modify ||
  fileStore.req?.type === "textImmutable" ||
  isMauroOutputFile;

const rawMauroFile = createRawMauroFile(fileStore.req!.url);

function createRawMauroFile(path: string) {
  //in      /files/gg_m2hv/m2hv.OUT.log
  //out    /api/raw-inline/gg_m2hv/m2hv.OUT.log
  return path
    .replace("/files/", "/api/raw-inline/")
    .replace("m2hv.OUT.log", "index.html");
}

function isMauroOutFile(filename: string) {
  return filename.match("^(m2lv|m2hv|m2ledmac|pdflatex)\\.OUT\\.log$") != null;
}

function isMauroM2HVOutFile(filename: string) {
  return isMauroOutFile(filename) && filename.startsWith("m2hv");
}

/* state vars relative al sistema di bacup/autosave */
let timerId: NodeJS.Timeout | undefined = undefined;
const timeoutInSeconds = 10;
let lastSavedRevision: number = -1;
let backupFileName: string | undefined = undefined;

onMounted(() => {
  window.addEventListener("keydown", keyEvent);
  window.addEventListener("wheel", handleScroll);

  if (!readonly)
    timerId = setInterval(function () {
      autoSave();
    }, timeoutInSeconds * 1000);

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
    readOnly:
      fileStore.req?.type === "textImmutable" ||
      isMauroOutFile(fileStore.req!.name),

    theme: "ace/theme/terminal",
    // theme: "ace/theme/chrome",

    mode: modelist.getModeForPath(fileStore.req!.name).mode,
    wrap: true,

    enableBasicAutocompletion: false,
    enableLiveAutocompletion: false,
    enableSnippets: true,

    behavioursEnabled: false,
    fontSize: "16px",
  });

  if (getTheme() === "dark") {
    editor.value!.setTheme("ace/theme/twilight");
  }

  editor.value.commands.addCommand({
    name: "showKeyboardShortcuts",
    bindKey: { win: "Ctrl-Alt-h", mac: "Command-Alt-h" },
    exec: function (editor) {
      ace.config.loadModule("ace/ext/keybinding_menu", function (module) {
        module.init(editor);
        editor.showKeyboardShortcuts();
      });
    },
  });
  editor.value.focus();
});

onBeforeUnmount(() => {
  window.removeEventListener("keydown", keyEvent);
  window.removeEventListener("wheel", handleScroll);
  editor.value?.destroy();

  window.clearInterval(timerId);
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
    lastSavedRevision = -1;

    //eliminiamo anche l'eventuale backup file
    if (backupFileName) {
      console.log("eliminating auto backup file ", backupFileName);
      await api.remove(backupFileName);
    }

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

const editorKeybindings = () => editor.value?.execCommand("showKeyboardShortcuts");

const editorSettings = () => editor.value?.execCommand("showSettingsMenu");

const editorSearch = () => editor.value?.execCommand("find");

const editorReplace = () => editor.value?.execCommand("replace");

const autoSave = () => {
  //console.log("autosaving");

  if (editor.value?.session.getUndoManager().isClean()) {
    //console.log("no changes, no autsaving");
    return;
  }

  if (
    editor.value?.session.getUndoManager().getRevision() == lastSavedRevision
  ) {
    //console.log("all changes already saved, no autsaving");
    return;
  }

  const lbl = document.querySelector(".autosave-label") as HTMLElement;
  if (lbl) {
    lbl.style.visibility = "visible";
    lbl.style.opacity = "1.0";
    lbl.title = "saving";
  }

  const _actualAutoSave = async () => {
    try {
      //create backup name
      const idx = route.path.lastIndexOf("/") + 1;

      //salva col nome di backup
      if (!backupFileName) {
        backupFileName = [
          route.path.slice(0, idx),
          "%23",
          route.path.slice(idx),
        ].join("");
      }

      if (lastSavedRevision < 0) {
        //al primo autosave creiamo il file se non c'e' e lo svuotiamo
        await api.post(backupFileName, "", true);
      }

      lastSavedRevision =
        editor.value?.session.getUndoManager().getRevision() || -1;

      await api.put(backupFileName, editor.value?.getValue());

      const lastsave = "last autosave at " + new Date().toLocaleTimeString();
      console.log("autosaving done: ", lastsave);

      if (lbl) {
        lbl.title = lastsave;
        lbl.style.opacity = "0.5";
      } else {
        console.log("lbl not available:", lastsave);
      }
    } catch (e: any) {
      $showError(e);
    }
  };

  _actualAutoSave();
};
</script>

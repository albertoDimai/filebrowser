<template>
  <ModalsContainer />
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { ModalsContainer, useModal } from "vue-final-modal";
import { storeToRefs } from "pinia";
import { useLayoutStore } from "@/stores/layout";

import BaseModal from "./BaseModal.vue";
import Help from "./Help.vue";
import Info from "./Info.vue";
import Delete from "./Delete.vue";
import DeleteUser from "./DeleteUser.vue";
import Download from "./Download.vue";
import Rename from "./Rename.vue";
import Move from "./Move.vue";
import Copy from "./Copy.vue";
import NewFile from "./NewFile.vue";
import NewDir from "./NewDir.vue";
import Replace from "./Replace.vue";
import ReplaceRename from "./ReplaceRename.vue";
import Share from "./Share.vue";
import ShareDelete from "./ShareDelete.vue";
import Upload from "./Upload.vue";
import Unzip from "./Unzip.vue";
import Mauro_M2L from "./Mauro_m2ledmac.vue";
import Mauro_PDF from "./Mauro_pdflatex.vue";
import Mauro_M2H from "./Mauro_m2hv.vue";

import DiscardEditorChanges from "./DiscardEditorChanges.vue";


const layoutStore = useLayoutStore();

const { currentPromptName } = storeToRefs(layoutStore);

const closeModal = ref<() => Promise<string>>();


const components = new Map<string, any>([
  ["info", Info],
  ["help", Help],
  ["delete", Delete],
  ["rename", Rename],
  ["move", Move],
  ["copy", Copy],
  ["unzip", Unzip],
  ["mauro_m2hv", Mauro_M2H],
  ["mauro_m2ledmac", Mauro_M2L],
  ["mauro_pdflatex", Mauro_PDF],
  ["newFile", NewFile],
  ["newDir", NewDir],
  ["download", Download],
  ["replace", Replace],
  ["replace-rename", ReplaceRename],
  ["share", Share],
  ["upload", Upload],
  ["share-delete", ShareDelete],
  ["deleteUser", DeleteUser],
  ["discardEditorChanges", DiscardEditorChanges],
]);

watch(currentPromptName, (newValue) => {
  if (closeModal.value) {
    closeModal.value();
    closeModal.value = undefined;
  }

  const modal = components.get(newValue!);
  if (!modal) return;

  const { open, close } = useModal({
    component: BaseModal,
    slots: {
      default: modal,
    },
  });

  closeModal.value = close;
  open();
});

window.addEventListener("keydown", (event) => {
  if (!layoutStore.currentPrompt) return;

  if (event.key === "Escape") {
    event.stopImmediatePropagation();
    layoutStore.closeHovers();
  }
});
</script>

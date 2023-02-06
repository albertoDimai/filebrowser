<template>
  <div>
    <component ref="currentComponent" :is="currentComponent"></component>
    <div v-show="showOverlay" @click="resetPrompts" class="overlay"></div>
  </div>
</template>

<script>
import Help from "./Help";
import Info from "./Info";
import Delete from "./Delete";
import Rename from "./Rename";
import Download from "./Download";
import Move from "./Move";
import Copy from "./Copy";
import NewFile from "./NewFile";
import NewDir from "./NewDir";
import Replace from "./Replace";
import ReplaceRename from "./ReplaceRename";
import Share from "./Share";
import Upload from "./Upload";
import ShareDelete from "./ShareDelete";
import Unzip from "./Unzip";
import { mapState } from "vuex";
import buttons from "@/utils/buttons";
import MauroPdflatex from "./Mauro_pdflatex.vue";
import MauroM2ledmac from "./Mauro_m2ledmac.vue";
import MauroM2hv from "./Mauro_m2hv.vue";

export default {
  name: "prompts",
  components: {
    Info,
    Delete,
    Rename,
    Download,
    Move,
    Copy,
    Share,
    NewFile,
    NewDir,
    Help,
    Replace,
    ReplaceRename,
    Upload,
    ShareDelete,
    Unzip,
    MauroPdflatex,
    MauroM2ledmac,
    MauroM2hv,
  },
  data: function () {
    return {
      pluginData: {
        buttons,
        store: this.$store,
        router: this.$router,
      },
    };
  },
  created() {
    window.addEventListener("keydown", (event) => {
      if (this.show == null) return;

      let prompt = this.$refs.currentComponent;

      // Esc!
      if (event.keyCode === 27) {
        event.stopImmediatePropagation();
        this.$store.commit("closeHovers");
      }

      // Enter
      if (event.keyCode == 13) {
        switch (this.show) {
          case "delete":
            prompt.submit();
            break;
          case "copy":
            prompt.copy(event);
            break;
          case "move":
            prompt.move(event);
            break;
          case "replace":
            prompt.showConfirm(event);
            break;
        }
      }
    });
  },
  computed: {
    ...mapState(["show", "plugins"]),
    currentComponent: function () {
      const matched =
        [
          "info",
          "help",
          "delete",
          "rename",
          "move",
          "copy",
          "newFile",
          "newDir",
          "download",
          "replace",
          "replace-rename",
          "share",
          "upload",
          "share-delete",
          "unzip",
          "mauro-pdflatex",
          "mauro-m2hv",
          "mauro-m2ledmac",
        ].indexOf(this.show) >= 0;

      return (matched && this.show) || null;
    },
    showOverlay: function () {
      return (
        this.show !== null && this.show !== "search" && this.show !== "more"
      );
    },
  },
  methods: {
    resetPrompts() {
      this.$store.commit("closeHovers");
    },
  },
};
</script>

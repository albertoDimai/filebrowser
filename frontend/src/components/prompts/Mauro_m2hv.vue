<template>
  <div class="card floating">
    <div class="card-title">
      <h2>{{ $t("prompts.mauro_m2hv") }}</h2>
    </div>

    <div class="card-content">
      <file-list
        ref="fileList"
        @update:selected="(val) => (dest = val)"
        tabindex="1"
      />

      <hr/>
      <label>Destination Directory Name:
    <input
        id="focus-prompt"
        class="input input--block"
        type="text"
        v-model.trim="outputName"
    />
      </label>


      <label>Commandline:
        <input
            id="focus-prompt"
            class="input input--block"
            type="text"
            v-model.trim="commandline"
        />
      </label>


    </div>

    <div
      class="card-action"
      style="display: flex; align-items: center; justify-content: space-between"
    >
      <template v-if="user.perm.create">
        <button
          class="button button--flat"
          @click="$refs.fileList.createDir()"
          :aria-label="$t('sidebar.newFolder')"
          :title="$t('sidebar.newFolder')"
          style="justify-self: left"
        >
          <span>{{ $t("sidebar.newFolder") }}</span>
        </button>
      </template>
      <div>
        <button
          class="button button--flat button--grey"
          @click="closeHovers"
          :aria-label="$t('buttons.cancel')"
          :title="$t('buttons.cancel')"
          tabindex="3"
        >
          {{ $t("buttons.cancel") }}
        </button>
        <button
          id="focus-prompt"
          class="button button--flat"
          @click="mauro_m2hv"
          :disabled="false"
          :aria-label="$t('buttons.mauro_m2hv')"
          :title="$t('buttons.mauro_m2hv')"
          tabindex="2"
        >
          {{ $t("buttons.mauro_m2hv") }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions, mapState } from "pinia";
import { useFileStore } from "@/stores/file";
import { useLayoutStore } from "@/stores/layout";
import { useAuthStore } from "@/stores/auth";
import FileList from "./FileList.vue";
import { files as api } from "@/api";
import buttons from "@/utils/buttons";
import * as upload from "@/utils/upload";

export default {
  name: "mauro_m2hv",
  components: { FileList },
  data: function () {
    return {
      outputName: "",
      commandline: "",
      current: window.location.pathname,
      dest: null,
    };
  },
  inject: ["$showError"],
  computed: {
    ...mapState(useFileStore, ["req", "selected"]),
    ...mapState(useAuthStore, ["user"]),
  },
  created() {
    this.outputName = this.computeOutputName();
  },
  methods: {
    ...mapActions(useLayoutStore, ["showHover", "closeHovers"]),
    computeOutputName: function () {

      if (this.selectedCount === 0 || this.selectedCount > 1) {
        // This shouldn't happen.
        return;
      }

      const selected = this.req.items[this.selected[0]].name
      //rimuoviamo l'extension ed aggiungiamo "_m2hv"
      return selected.substring(0, selected.lastIndexOf('.')) + "_m2hv";
    },
    mauro_m2hv: async function (event) {

      event.preventDefault();

      //uso questo oggetto fatto per il modve per riusare la funziona conflict poco sotto
      const item = {
        from: this.req.items[this.selected[0]].url,
        to: this.dest + this.outputName,
        name: this.outputName,
      }

      const items = []
      items.push(item)

      let dstItems = (await api.fetch(this.dest)).items;

      let conflict = upload.checkConflict(items, dstItems);

      let overwrite = false;
      let rename = false;


      if (conflict) {
        this.showHover({
          prompt: "replace-rename",
          confirm: (event, option) => {
            overwrite = option == "overwrite";
            rename = option == "rename";
            event.preventDefault();
            this.closeHovers();
            action(overwrite, rename);
          },
        });

        return;
      }


      let action = async (overwrite, rename) => {
        buttons.loading("mauro_m2hv");

        await api
            .mauro("m2hv",item, encodeURIComponent(this.commandline), overwrite, rename)
            .then(() => {
              buttons.success("mauro_m2hv");
              this.$router.push({ path: this.dest });
            })
            .catch((e) => {
              buttons.done("mauro_m2hv");
              this.$showError(e);
            });
      };
      action(overwrite, rename);
    },
  },
};
</script>

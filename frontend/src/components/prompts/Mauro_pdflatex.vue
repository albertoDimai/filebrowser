<template>
  <div class="card floating">
    <div class="card-title">
      <h2>{{ $t("prompts.mauro_pdflatex") }}</h2>
    </div>

    <div class="card-content" >
      <file-list
        ref="fileList"
        @update:selected="(val) => (dest = val)"
        tabindex="1"
      />
    </div>

    <div
      class="card-action"
      style="display: flex; align-items: center; justify-content: space-between"
    >
      <template v-if="user.perm.create">
        <button v-if="false"
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
          @click="mauro_pdflatex"
          :disabled="false"
          :aria-label="$t('buttons.mauro_pdflatex')"
          :title="$t('buttons.mauro_pdflatex')"
          tabindex="2"
        >
          {{ $t("buttons.mauro_pdflatex") }}
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
  name: "mauro_pdflatex",
  components: { FileList },
  data: function () {
    return {
      current: window.location.pathname,
      dest: null,
    };
  },
  inject: ["$showError"],
  computed: {
    ...mapState(useFileStore, ["req", "selected"]),
    ...mapState(useAuthStore, ["user"]),
  },
  methods: {
    ...mapActions(useLayoutStore, ["showHover", "closeHovers"]),
    mauro_pdflatex: async function (event) {
      event.preventDefault();
      let items = [];

      const item = {
        from: this.req.items[this.selected[0]].url,
        //to: this.current +"/"+ this.outputName,
        //name: this.outputName,
      }

      let action = async (overwrite, rename) => {
        buttons.loading("mauro_pdflatex");

        await api
          .mauro("pdflatex", item,"", overwrite, rename)
          .then(() => {
            buttons.success("mauro_pdflatex");
            this.$router.push({ path: this.dest });
          })
          .catch((e) => {
            buttons.done("mauro_pdflatex");
            this.$showError(e);
          });
      };

      //let dstItems = (await api.fetch(this.dest)).items;
      //let conflict = upload.checkConflict(items, dstItems);

      let conflict = false;

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

      action(overwrite, rename);
    },
  },
};
</script>

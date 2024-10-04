<template>
  <div class="card floating" style="max-width: 40em;">
    <div class="card-title">
      <h2>{{ $t("prompts.mauro_m2hv") }}</h2>
    </div>

    <div class="card-content">
      <file-list
        ref="fileList"
        @update:selected="(val) => {eventuallyChangedDestination();}"
        tabindex="1"
      />

      <hr style="margin-bottom: 1.5em;"/>

      <div style="display: inline-block; width: calc( 100% - 90px);">
      <label>Destination Directory Name:
        <input style="margin-bottom: 1em;"
        class="input input--block"
        type="text"
        v-on:keyup="eventuallyChangedDestination"
        v-model.trim="outputName"/>
      </label>
      </div>

    <div ref="hideable" style="display: inline-block; margin-left: 10px; vertical-align: top; transition: opacity .6s;">
    <label>Overwrite:
      <input style="margin-bottom: 1em; margin-top: 10px;"
             class="input input--block"
             type="checkbox"
             ref="overwrite"
             @click="eventuallyChangedDestination"
             v-model.trim="overwrite"/>
    </label>
  </div>



      <label>m2hv options:
        <input
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
<!--      <template v-if="user.perm.create">-->
<!--        <button-->
<!--          class="button button&#45;&#45;flat"-->
<!--          @click="$refs.fileList.createDir()"-->
<!--          :aria-label="$t('sidebar.newFolder')"-->
<!--          :title="$t('sidebar.newFolder')"-->
<!--          style="justify-self: left"-->
<!--        >-->
<!--          <span>{{ $t("sidebar.newFolder") }}</span>-->
<!--        </button>-->
<!--      </template>-->
      <div style="width: 100%;">
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
          :disabled="isSaveDisabled"
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
      fileList: null,
      outputName: "",
      commandline: "",
      current: window.location.pathname,
      dest: null,
      mounted: false,
      saveDisabled: true,
      overwrite: false,
      hideable: null
    };
  },
  inject: ["$showError"],
  computed: {
    ...mapState(useFileStore, ["req", "selected"]),
    ...mapState(useAuthStore, ["user"]),
    isSaveDisabled: function() {
      return this.saveDisabled;
    }
  },
  created() {
    this.outputName = this.computeOutputName();
  },
  mounted() {
      //this waits for subcompenents being mounted and starts the show
    this.mounted = true;
    this.eventuallyChangedDestination();

  },
  methods: {
    ...mapActions(useLayoutStore, ["showHover", "closeHovers"]),
    eventuallyChangedDestination: function() {

        if(!this.mounted) {
          //console.log("Mauro_m2hv still not mounted");
          return;
        }

      let conflicting = false;
        //check for conflicts
        for( let dir of this.$refs.fileList.items) {
          if(this.outputName == dir.name) {
              conflicting = true;
              break;
          }
        }

        //console.log(this.$refs.overwrite.checked)
        //console.log("on",this.$refs.fileList.current , this.$refs.fileList.items);

      if(conflicting) {
        this.$refs.hideable.style.opacity = '1.0';
        if (!this.$refs.overwrite.checked)
          this.saveDisabled = true;
        else
          this.saveDisabled = false;

      } else {
        this.$refs.hideable.style.opacity = '0.0';
        this.saveDisabled = false;
      }
    },

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

      let action = async (overwrite, rename) => {
        buttons.loading("mauro_m2hv");

        const item = {
          from: this.req.items[this.selected[0]].url,
          to: this.current +"/"+ this.outputName,
          name: this.outputName,
        }

        await api
            .mauro("m2hv",item, encodeURIComponent(this.commandline), overwrite, rename)
            .then(() => {
              const redirect_destination = this.outputName + "/m2hv.OUT.log";
              buttons.success("mauro_m2hv");
              this.$router.push({path: redirect_destination}); //convenzione
            })
            .catch((e) => {
              buttons.done("mauro_m2hv");
              this.$showError(e);
            });
      };

      action(false, false);
    },
  },
};
</script>

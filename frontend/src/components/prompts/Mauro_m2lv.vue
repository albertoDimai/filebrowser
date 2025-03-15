<template>
  <div class="card floating" style="max-width: 40em;">
    <div class="card-title">
      <h2>{{ $t("prompts.mauro_m2lv") }}</h2>
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



      <label>m2lv options:
        <input
            class="input input--block"
            type="text"
            v-model.trim="commandline"
        />
      </label>


    </div>

    <div
        class="card-action"
        style="
      display: flex; align-items: center; justify-content: space-between;
      padding-bottom: 14px;"
    >
      <button
          id="help-button"
          class="button button--flat button--grey"
          style="float: left"
          @click="mauro_m2lv_help"
          :aria-label="$t('buttons.command_help')"
          :title="$t('buttons.command_help')"
          tabindex="4"
      >
        <i class="material-icons" style="font-size: 2rem;">help</i>
      </button>
      <div style="flex-grow: 1;"></div>
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
          @click="mauro_m2lv"
          :disabled="isSaveDisabled"
          :aria-label="$t('buttons.mauro_m2lv')"
          :title="$t('buttons.mauro_m2lv')"
          tabindex="2"
          style="display: flex;
          align-items: center;
          gap: 5px;">
          <i class="material-icons">start</i>
          {{ $t("buttons.mauro_m2lv") }}
        </button>
      </div>
    </div>


  <div class="card floating" style="max-width: 80vw;" :hidden="isHelpHidden">
    <div class="card-title"><h2>m2lv commandline help</h2>
      <i class="material-icons" @click="close_help" style="cursor: pointer">close</i>
    </div>
    <div class="card-content">
      <pre class="code">{{helpText}}</pre>
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
  name: "mauro_m2lv",
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
      helpHidden: true,
      helpText: null,
      helpLoaded: false,
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
    },
    isHelpHidden: function () {
      return this.helpHidden;
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
          console.log("Mauro_m2lv still not mounted");
          return;
        }

      let conflicting = false;
        //check for conflicts
        for( const dir of this.$refs.fileList.items) {
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
      //rimuoviamo l'extension ed aggiungiamo "_m2lv"
      return selected.substring(0, selected.lastIndexOf('.')) + "_m2lv";
    },
    mauro_m2lv: async function (event) {

      event.preventDefault();

      const action = async (overwrite, rename) => {
        buttons.loading("mauro_m2lv");

        const item = {
          from: this.req.items[this.selected[0]].url,
          to: this.$refs.fileList.current + this.outputName,
          name: this.outputName,
        }

        await api
            .mauro("m2lv",item, encodeURIComponent(this.commandline), rename)
            .then(() => {
              buttons.success("mauro_m2lv");
              this.$router.push({path: item.to + "/m2lv.OUT.log"}); //convenzione
            })
            .catch((e) => {
              buttons.done("action");
              this.$showError(e);
            });
      };
      action(false, false);
    },
    close_help: async function () {
      this.helpHidden = true;
    },
    mauro_m2lv_help: async function (event) {

      event.preventDefault();

      if (!this.helpLoaded) {
        console.log("caricamento")
        this.helpLoaded = true

        buttons.loading("help");
        await api
            .mauro_help("m2lv")
            .then((response) => {
              buttons.success("help");
              this.helpText = response;
              this.helpHidden = false;
            })
            .catch((e) => {
              buttons.done("help");
              this.$showError(e);
            });

      } else {
        this.helpHidden = false;
      }



    },
  },
};
</script>

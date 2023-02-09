<template>
    <div class="card floating">
      <div class="card-title">
        <h2>{{ $t("prompts.mauro_m2hv") }}</h2>
      </div>
  
      <div class="card-content">
        Execute m2hv on the file ?
        <div style="padding-top: 15px;">
          <input style="margin: 5px;" type="checkbox" id="checkbox" ref="theCheckbox" checked="true">
          <label for="checkbox">load result</label>
        </div>
      </div>
  
      <div class="card-action">
        <button
          class="button button--flat button--grey"
          @click="$store.commit('closeHovers')"
          :aria-label="$t('buttons.cancel')"
          :title="$t('buttons.cancel')"
        >
          {{ $t("buttons.cancel") }}
        </button>
        <button
          class="button button--flat"
          @click="mauro_m2hv"
          :aria-label="$t('buttons.mauro_m2hv')"
          :title="$t('buttons.mauro_m2hv')"
        >
          {{ $t("buttons.mauro_m2hv") }}
        </button>
      </div>
    </div>
  </template>
  
  <script>
  import { mapState } from "vuex";
  // import FileList from "./FileList";
  import { files as api } from "@/api";
  import buttons from "@/utils/buttons";
  
  export default {
    name: "mauro_m2hv",
    // components: { FileList },
    data: function () {
      return {
        current: window.location.pathname,
        dest: null,
      };
    },
    computed: mapState(["req", "selected"]),
    methods: {
      mauro_m2hv: async function (event) {
        event.preventDefault();
        let items = [];
  
        for (let item of this.selected) {
          items.push({
            from: this.req.items[item].url
          });
        }
  
        let action = async () => {
          const load_result = this.$refs.theCheckbox.checked;
          buttons.loading("mauro_m2hv");

          await api
            .mauro("m2hv",items)
            .then(() => {
              buttons.success("mauro_m2hv");
              if(load_result)
                this.$router.push({ path: items[0].from + ".m2hv.OUT.log" }); //convenzione
              else
                this.$router.push({ path: "#" + Math.random() });
            })
            .catch((e) => {
              buttons.done("mauro_m2hv");
              this.$showError(e);
            });
        };
        action();
      },
    },
  };
  </script>
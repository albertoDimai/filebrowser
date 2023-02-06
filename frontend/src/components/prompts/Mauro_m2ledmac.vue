<template>
    <div class="card floating">
      <div class="card-title">
        <h2>{{ $t("prompts.mauro_m2ledmac") }}</h2>
      </div>
  
      <div class="card-content">
        Execute m2ledmac on the file ?
<!--        <file-list @update:selected="(val) => (dest = val)"></file-list>-->
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
          @click="mauro_m2ledmac"
          :aria-label="$t('buttons.mauro_m2ledmac')"
          :title="$t('buttons.mauro_m2ledmac')"
        >
          {{ $t("buttons.mauro_m2ledmac") }}
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
    name: "mauro_m2ledmac",
    // components: { FileList },
    data: function () {
      return {
        current: window.location.pathname,
        dest: null,
      };
    },
    computed: mapState(["req", "selected"]),
    methods: {
      mauro_m2ledmac: async function (event) {
        event.preventDefault();
        let items = [];
  
        for (let item of this.selected) {
          items.push({
            from: this.req.items[item].url
          });
        }
  
        let action = async () => {
          buttons.loading("mauro_m2ledmac");
  
          await api
            .mauro("m2ledmac",items)
            .then(() => {
              buttons.success("mauro_m2ledmac");
              this.$router.push({ path: "#" + Math.random() });

            })
            .catch((e) => {
              buttons.done("mauro_m2ledmac");
              this.$showError(e);
            });
        };
        action();
      },
    },
  };
  </script>
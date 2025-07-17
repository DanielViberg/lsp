<script setup>
import t from './test.vue'

const props = defineProps(['myProp1'])
const thisIsMyVariabe = ref();

</script>

<style>
.test {
  display: grid;
  grid-auto-columns: 1fr;
  background: gray;
}
</style>

<template>
  <div :class="thisIsMyVariabe">
  </div>
</template>

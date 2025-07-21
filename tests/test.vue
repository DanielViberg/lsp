<script setup>

const thisIsAVariable = defineProps()

</script>
<style>
.test {
	display: grid;
}
</style>

<template>
	<div :class="thisIsAVariable" :style="() => console.log()">
		<div :class="thisIsAVariable"></div>
	</div>
</template>

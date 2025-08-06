<script setup>

const thisIsAVariable = defineProps()
const thisI2Variable = defineSlots()

</script>
<style>
.test {
	display: grid;
	align-self: center;
}
</style>

<template>
	<div :class="thisI2Variable" :style="test">
		<div :class="thisI2Variable"></div>
	</div>
</template>

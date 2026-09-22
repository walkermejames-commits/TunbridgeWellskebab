import { Stack } from "expo-router";
export default function Layout(){ return <Stack screenOptions={{ headerStyle:{backgroundColor:"#101822"},headerTintColor:"#fff" }}><Stack.Screen name="index" options={{title:"TWK Driver · Demo"}} /></Stack>; }

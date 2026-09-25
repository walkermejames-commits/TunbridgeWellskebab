export type Variant = { name: string; price: number };
export type MenuItem = {
  id: string;
  category: string;
  name: string;
  description?: string;
  price: number;
  variants?: Variant[];
  configurable?: boolean;
  available: boolean;
};

const kebabVariants = (medium: number, large: number): Variant[] => [
  { name: "Medium", price: medium },
  { name: "Large", price: large },
];

const kebabs = [
  ["Doner Kebab", "Served in pitta & salad. Minced lamb roasted on an upright spit.", 800, 1000],
  ["Chicken Doner", "Served in pitta & salad. Marinated chicken pieces roasted on an upright spit.", 800, 1000],
  ["Chicken Shish Kebab", "Served in pitta & salad. Marinated cubes of chicken grilled on skewers.", 900, 1250],
  ["Lamb Shish", "Served in pitta & salad. Marinated cubes of lamb grilled on skewers.", 900, 1250],
  ["Kofte Kebab", "Served in pitta & salad. Seasoned minced lamb grilled on skewers.", 900, 1250],
  ["Doner Meat, Chips", undefined, 800, 1000],
  ["Doner Meal & Chips in Pitta", undefined, 1000, undefined],
  ["Chicken Meat & Chips", undefined, 800, 1000],
  ["Mixed Doner Meat & Chips", undefined, 1100, undefined],
  ["Lamb Doner Wrap", undefined, 800, 1000],
  ["Chicken Doner Wrap", undefined, 800, 1000],
  ["Portion Of Doner Meat", undefined, 800, 1000],
  ["Mixed Kebab Shish, Kofte & Mixture Of Doner", undefined, 1700, undefined],
  ["Super Best Shish, Chicken, Kofte & Mixture Of Doner & Chips", undefined, 2500, undefined],
] as const;

const combinations = [
  ["Lamb Shish & Doner", 1250], ["Lamb Shish & Chicken Shish", 1250],
  ["Chicken Shish & Doner", 1250], ["Chicken Doner & Lamb Doner", 1250],
  ["Lamb Shish & Kofte", 1250], ["Chicken Shish & Kofte", 1250],
  ["Lamb Kofte & Doner", 1250],
] as const;

const starters = [
  ["Humus", 500], ["Stuffed Vine Leaves", 500], ["Garlic Mushroom", 500],
  ["Onion Rings (10 pcs)", 500], ["Mozzarella Stick", 500], ["Halloumi Cheese", 500],
] as const;
const burgers = [
  ["1/4 Pounder", "Served with salad garnish.", 500], ["1/4 Pounder With Cheese", "Served with salad garnish.", 550],
  ["1/4 Pounder With Meat Doner", "Served with salad garnish.", 800], ["1/2 Pounder With Cheese", "Served with salad garnish.", 700],
  ["1/2 Pounder With Meat Doner", "Served with salad garnish.", 1000], ["Vege Burger", "Served with salad garnish.", 500],
  ["Chicken Burger", "Served with salad garnish.", 550], ["Chicken Sandwich (Supreme)", "Served with salad garnish.", 700],
  ["Giant Burger With Cheese", "Served with salad garnish.", 1000], ["Doner In Roll", "Served with salad garnish.", 800],
] as const;
const chicken = [
  ["8 Chicken Wings With Chips - Grilled", 900], ["12 Chicken Nuggets & Chips", 850],
  ["8 Chicken Nuggets & Chips", 750], ["20 Pcs Popcorn Chicken", 750], ["Roast Chicken With Chips", 850],
] as const;
const fish = [["Cod & Chips", 850], ["Scampi & Chips (10 Pcs)", 850]] as const;
const meals = [
  ["Meal 1 - 1/4 Pounder, Chips & Drink", 900], ["Meal 2 - 1/2 Pounder, Chips & Drink", 1100],
  ["Meal 3 - Chicken Sandwich, Chips & Drink", 1100], ["Meal 4 - Chicken Twister, Chips & Drink", 1100],
  ["Meal 5 - Lamb Doner Wrap, Chips & Drink", 1100], ["Meal 6 - Chicken Doner Wrap, Chips & Drink", 1100],
] as const;

const make = (category: string, index: number, name: string, price: number, description?: string, variants?: Variant[]): MenuItem => ({
  id: `${category.toLowerCase().replaceAll(" ", "-")}-${index + 1}`,
  category, name, price, description, variants, configurable: category === "Kebabs" || category === "Combination Kebabs", available: true,
});

export const menu: MenuItem[] = [
  ...starters.map(([name, price], i) => make("Starters", i, name, price)),
  ...kebabs.map(([name, description, price, large], i) => make("Kebabs", i, name, price, description, large ? kebabVariants(price, large) : undefined)),
  ...combinations.map(([name, price], i) => make("Combination Kebabs", i, name, price, "Served with pitta bread & salad.", undefined)),
  ...burgers.map(([name, description, price], i) => make("Burgers", i, name, price, description)),
  ...chicken.map(([name, price], i) => make("Chicken", i, name, price)),
  ...fish.map(([name, price], i) => make("Fish", i, name, price)),
  ...meals.map(([name, price], i) => make("Meals", i, name, price)),
];

export const categories = ["Starters", "Kebabs", "Combination Kebabs", "Burgers", "Chicken", "Fish", "Meals"];
export const modifierOptions = ["No salad", "Extra salad", "Chilli sauce", "Garlic sauce", "No sauce"];

/**
 * @file
 * @copyright 2024
 * @author Cheekybrdy (https://github.com/cheekybrdy)
 * @license MIT
 */

export interface BrazierData {
  sealed: boolean;
  pantheon_selected: boolean;
  name: string;
  pantheons: Pantheons[];
}

export interface Pantheons {
  category: string;
  brazier: BrazierID[];
}

export interface BrazierID {
  id: string;
}

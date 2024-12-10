/**
 * @file
 * @copyright 2024
 * @author Cheekybrdy (https://github.com/cheekybrdy)
 * @license MIT
 */

export interface BrazierData {
  dialing: boolean;
  inCall: boolean;
  lastOffered: string;
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
